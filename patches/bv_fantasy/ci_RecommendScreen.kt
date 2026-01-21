package dev.aaa1115910.bv.tv.screens.main.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.unit.dp
import dev.aaa1115910.biliapi.entity.ugc.UgcItem
import dev.aaa1115910.bv.tv.component.LoadingTip
import dev.aaa1115910.bv.entity.carddata.VideoCardData
import dev.aaa1115910.bv.tv.R
import dev.aaa1115910.bv.tv.activities.video.UpInfoActivity
import dev.aaa1115910.bv.tv.activities.video.VideoInfoActivity
import dev.aaa1115910.bv.tv.component.videocard.SmallVideoCard
import dev.aaa1115910.bv.tv.util.ProvideListBringIntoViewSpec
import dev.aaa1115910.bv.viewmodel.home.RecommendViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.koin.androidx.compose.koinViewModel

@Composable
fun RecommendScreen(
    modifier: Modifier = Modifier,
    lazyGridState: LazyGridState = rememberLazyGridState(),
    recommendViewModel: RecommendViewModel = koinViewModel()
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    // 纯基础API预加载逻辑：延迟循环检查，无任何冷门依赖
    LaunchedEffect(lazyGridState, recommendViewModel) {
        while (true) {
            delay(300L)
            val listSize = recommendViewModel.recommendVideoList.size
            // 跳过无数据/加载中/无更多的情况
            if (listSize == 0 || recommendViewModel.loading || !recommendViewModel.hasMore) continue
            
            // 获取可见区域最后一个item索引
            val lastVisibleIndex = lazyGridState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: -1
            // 提前24项触发加载
            if (lastVisibleIndex >= listSize - 24) {
                scope.launch(Dispatchers.IO) {
                    recommendViewModel.loadMore()
                }
            }
        }
    }

    val onClickVideo: (UgcItem) -> Unit = { ugcItem ->
        VideoInfoActivity.actionStart(context, ugcItem.aid)
    }

    val onLongClickVideo: (UgcItem) -> Unit = { ugcItem ->
        UpInfoActivity.actionStart(
            context,
            mid = ugcItem.authorId,
            name = ugcItem.author,
            face = ugcItem.authorFace
        )
    }

    val padding = dimensionResource(R.dimen.grid_padding)
    val spacedBy = dimensionResource(R.dimen.grid_spacedBy)
    ProvideListBringIntoViewSpec {
        LazyVerticalGrid(
            modifier = modifier.fillMaxSize(),
            columns = GridCells.Fixed(4),
            state = lazyGridState,
            contentPadding = PaddingValues(padding),
            verticalArrangement = Arrangement.spacedBy(spacedBy),
            horizontalArrangement = Arrangement.spacedBy(spacedBy)
        ) {
            itemsIndexed(recommendViewModel.recommendVideoList) { _, item ->
                SmallVideoCard(
                    data = remember(item.aid) {
                        // 核心修复：处理Java Long类型到目标类型的转换，无高阶函数
                        // 1. play字段：转为Long?，匹配VideoCardData的Long?参数
                        val playValue: Long? = if (item.play != null && item.play != -1L) {
                            item.play
                        } else {
                            null
                        }

                        // 2. danmaku字段：转为Int?，匹配VideoCardData的Int?参数
                        val danmakuValue: Int? = if (item.danmaku != null) {
                            val danmakuLong = item.danmaku.toLong()
                            // 安全转换：判断是否在Int范围内，避免溢出
                            if (danmakuLong >= Int.MIN_VALUE && danmakuLong <= Int.MAX_VALUE) {
                                val danmakuInt = danmakuLong.toInt()
                                if (danmakuInt != -1) danmakuInt else null
                            } else {
                                null
                            }
                        } else {
                            null
                        }

                        VideoCardData(
                            avid = item.aid,
                            title = item.title,
                            cover = item.cover,
                            play = playValue,
                            danmaku = danmakuValue,
                            upName = item.author,
                            time = item.duration * 1000L,
                            pubTime = item.pubTime
                        )
                    },
                    onClick = { onClickVideo(item) },
                    onLongClick = { onLongClickVideo(item) },
                    onFocus = {}
                )
            }

            if (recommendViewModel.loading) {
                item(span = { GridItemSpan(maxLineSpan) }) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        LoadingTip()
                    }
                }
            }
        }
    }
}