package dev.aaa1115910.bv.tv.screens.main.home

import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.dimensionResource
import androidx.compose.ui.res.stringResource
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
import org.koin.androidx.compose.koinViewModel
import kotlinx.coroutines.delay //#+

@Composable
fun DynamicsScreen(
    modifier: Modifier = Modifier,
    lazyGridState: LazyGridState = rememberLazyGridState(),
    dynamicViewModel: DynamicViewModel = koinViewModel()
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    //#-var currentFocusedIndex by remember { mutableIntStateOf(-1) }
    // 纯基础API预加载逻辑：延迟循环检查，无任何冷门依赖
    LaunchedEffect(lazyGridState, dynamicViewModel) {                                                     //#+
        while (true) {                                                                                    //#+
            delay(1L)                                                                                     //#+
            val listSize = dynamicViewModel.dynamicVideoList.size                                         //#+
            // 跳过无数据/加载中/无更多的情况                                                             //#+
            //if (listSize == 0 || dynamicViewModel.loading || !dynamicViewModel.hasMore) continue        //#+
            if (listSize == 0) continue                                                                   //#+
                                                                                                          //#+
            // 获取可见区域最后一个item索引                                                               //#+
            val lastVisibleIndex = lazyGridState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: -1    //#+
            // 提前24项触发加载                                                                           //#+
            if (lastVisibleIndex >= listSize - 24) {                                                      //#+
                scope.launch(Dispatchers.IO) {                                                            //#+
                    dynamicViewModel.loadMoreVideo()                                                           //#+
                }                                                                                         //#+
            }                                                                                             //#+
        }                                                                                                 //#+
    }                                                                                                     //#+
    //#-val shouldLoadMore by remember {
    //#-    derivedStateOf { dynamicViewModel.dynamicVideoList.isNotEmpty() && currentFocusedIndex + 12 > dynamicViewModel.dynamicVideoList.size }
    //#-}
    //#-val showTip by remember {
    //#-    derivedStateOf { dynamicViewModel.dynamicVideoList.isNotEmpty() && currentFocusedIndex >= 0 }
    //#-}

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

    //#-//不能直接使用 LaunchedEffect(currentFocusedIndex)，会导致整个页面重组
    //#-LaunchedEffect(shouldLoadMore) {
    //#-    if (shouldLoadMore) {
    //#-        scope.launch(Dispatchers.IO) {
    //#-            dynamicViewModel.loadMoreVideo()
    //#-        }
    //#-    }
    //#-}

    if (dynamicViewModel.isLogin) {
        val padding = dimensionResource(R.dimen.grid_padding)
        val spacedBy = dimensionResource(R.dimen.grid_spacedBy)
        //#-if (showTip) {
        //#-    Text(
        //#-        modifier = Modifier.fillMaxWidth().offset(x = (-20).dp, y = (-8).dp),
        //#-        text = stringResource(R.string.entry_follow_screen),
        //#-        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
        //#-        fontSize = 12.sp,
        //#-        textAlign = TextAlign.End
        //#-    )
        //#-}
        ProvideListBringIntoViewSpec {
            LazyVerticalGrid(
                modifier = modifier
                    .fillMaxSize()
                    .onFocusChanged {} //#+
                    //#-.onFocusChanged{
                    //#-    if (!it.isFocused) {
                    //#-        currentFocusedIndex = -1
                    //#-    }
                    //#-}
                    .onPreviewKeyEvent {
                        if(it.type == KeyEventType.KeyUp && it.key == Key.Menu) {
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
                itemsIndexed(dynamicViewModel.dynamicVideoList) { index, item ->
                    SmallVideoCard(
                        data = remember(item.aid) {
                            // 核心修复：处理Java Long类型到目标类型的转换，无高阶函数             //#+
                            // 1. play字段：转为Long?，匹配VideoCardData的Long?参数                //#+
                            val playValue: Long? = if (item.play != null && item.play != -1L) {    //#+
                                item.play                                                          //#+
                            } else {                                                               //#+
                                null                                                               //#+
                            }                                                                      //#+
                            // 2. danmaku字段：转为Int?，匹配VideoCardData的Int?参数               //#+
                            val danmakuValue: Int? = if (item.danmaku != null) {                   //#+
                                val danmakuLong = item.danmaku                                     //#+
                                // 安全转换：判断是否在Int范围内，避免溢出                         //#+
                                if (danmakuLong >= Int.MIN_VALUE && danmakuLong <= Int.MAX_VALUE) {//#+
                                    val danmakuInt = danmakuLong.toInt()                           //#+
                                    if (danmakuInt != -1) danmakuInt else null                     //#+
                                } else {                                                           //#+
                                    null                                                           //#+
                                }                                                                  //#+
                            } else {                                                               //#+
                                null                                                               //#+
                            }                                                                      //#+
                            
                            
                            VideoCardData(
                                avid = item.aid,
                                title = item.title,
                                cover = item.cover,
                                //#-play = item.play,
                                //#-danmaku = item.danmaku,
                                play = playValue, //#+
                                danmaku = danmakuValue, //#+
                                upName = item.author,
                                time = item.duration * 1000L,
                                pubTime = item.pubTime,
                                isChargingArc = item.isChargingArc,
                                badgeText = item.chargingArcBadge
                            )
                        },
                        onClick = { onClickVideo(item) },
                        onLongClick = {onLongClickVideo(item) },
                        onFocus = { currentFocusedIndex = index }
                    )
                }

                if (dynamicViewModel.loadingVideo) {
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            LoadingTip()
                        }
                    }
                }

                if (!dynamicViewModel.videoHasMore) {
                    item(span = { GridItemSpan(maxLineSpan) }) {
                        Text(
                            text = "没有更多了捏",
                            color = Color.White
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
            Text(text = "请先登录")
        }
    }
}
