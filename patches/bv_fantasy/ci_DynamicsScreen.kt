package dev.aaa1115910.bv.tv.screens.main.home
import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.Text
import dev.aaa1115910.biliapi.entity.user.DynamicVideo
import dev.aaa1115910.bv.tv.component.LoadingTip
import dev.aaa1115910.bv.entity.carddata.VideoCardData
import dev.aaa1115910.bv.entity.proxy.ProxyArea
import dev.aaa1115910.bv.tv.R
import dev.aaa1115910.bv.tv.activities.user.FollowActivity
import dev.aaa1115910.bv.tv.activities.video.UpInfoActivity
import dev.aaa1115910.bv.tv.activities.video.VideoInfoActivity
import dev.aaa1115910.bv.tv.component.videocard.SmallVideoCard
import dev.aaa1115910.bv.tv.util.ProvideListBringIntoViewSpec
import dev.aaa1115910.bv.viewmodel.home.DynamicViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.snapshotFlow
import org.koin.androidx.compose.koinViewModel

// 强制导入所有必要依赖（解决 snapshotFlow 找不到问题）
import kotlinx.coroutines.flow.snapshotFlow as snapshotFlowAlias

@Composable
fun DynamicsScreen(
    modifier: Modifier = Modifier,
    lazyGridState: LazyGridState = rememberLazyGridState(),
    dynamicViewModel: DynamicViewModel = koinViewModel()
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    // 1. 彻底解决 snapshotFlow 引用问题：用别名+明确类型
    val visibleItemIndexFlow: Flow<Int?> = snapshotFlowAlias {
        lazyGridState.layoutInfo.visibleItemsInfo.lastOrNull()?.index
    }

    // 2. 加载触发逻辑（无冗余、无废弃API、类型完全明确）
    LaunchedEffect(lazyGridState, dynamicViewModel) {
        visibleItemIndexFlow
            .filter { index ->
                index != null 
                && dynamicViewModel.dynamicVideoList.isNotEmpty() 
                && index >= dynamicViewModel.dynamicVideoList.size - 15
                && !dynamicViewModel.loading
            }
            .collect {
                scope.launch(Dispatchers.IO) {
                    dynamicViewModel.loadMore()
                }
            }
    }

    val onClickVideo: (DynamicVideo) -> Unit = { dynamic ->
        VideoInfoActivity.actionStart(
            context = context,
            aid = dynamic.aid,
            proxyArea = ProxyArea.checkProxyArea(dynamic.title)
        )
    }

    val onLongClickVideo: (DynamicVideo) -> Unit = { dynamic ->
        UpInfoActivity.actionStart(
            context,
            mid = dynamic.authorId,
            name = dynamic.author,
            face = dynamic.authorFace
        )
    }

    if (dynamicViewModel.isLogin) {
        val padding = dimensionResource(R.dimen.grid_padding)
        val spacedBy = dimensionResource(R.dimen.grid_spacedBy)

        ProvideListBringIntoViewSpec {
            LazyVerticalGrid(
                modifier = modifier
                    .fillMaxSize()
                    .onFocusChanged {}
                    .onPreviewKeyEvent {
                        if (it.type == KeyEventType.KeyUp && it.key == Key.Menu) {
                            context.startActivity(Intent(context, FollowActivity::class.java))
                            return@onPreviewKeyEvent true
                        }
                        false
                    },
                columns = GridCells.Fixed(4),
                state = lazyGridState,
                contentPadding = PaddingValues(padding),
                verticalArrangement = Arrangement.spacedBy(spacedBy),
                horizontalArrangement = Arrangement.spacedBy(spacedBy)
            ) {
                itemsIndexed(dynamicViewModel.dynamicVideoList) { _, item ->
                    SmallVideoCard(
                        data = remember(item.aid) {
                            // 3. 彻底解决 Long/Int 类型不匹配：明确用 -1L（匹配 DynamicVideo 中 play/danmaku 的 Long 类型）
                            VideoCardData(
                                avid = item.aid,
                                title = item.title,
                                cover = item.cover,
                                play = item.play.takeIf { it != -1L }, // 强制 Long 类型匹配
                                danmaku = item.danmaku.takeIf { it != -1L }, // 强制 Long 类型匹配
                                upName = item.author,
                                time = item.duration * 1000L,
                                pubTime = item.pubTime,
                                isChargingArc = item.isChargingArc,
                                badgeText = item.chargingArcBadge
                            )
                        },
                        onClick = { onClickVideo(item) },
                        onLongClick = { onLongClickVideo(item) },
                        onFocus = {}
                    )
                }

                // 加载中状态（简化布局，无冗余）
                if (dynamicViewModel.loading) {
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            LoadingTip()
                        }
                    }
                }

                // 无更多数据状态（样式统一）
                if (!dynamicViewModel.hasMore && !dynamicViewModel.loading) {
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        Text(
                            modifier = Modifier.fillMaxWidth(),
                            text = "没有更多了捏",
                            color = Color.White,
                            fontSize = 14.sp,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
        }
    } else {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "请先登录",
                color = Color.White,
                fontSize = 16.sp
            )
        }
    }
}
