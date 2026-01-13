package dev.aaa1115910.bv.tv.screens.main.home

import android.content.Intent
import android.view.View
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
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.FocusState
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.focus.onFocusEvent
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
import androidx.compose.ui.focus.FocusStateImpl
import android.view.FocusFinder

@Composable
fun DynamicsScreen(
    modifier: Modifier = Modifier,
    lazyGridState: LazyGridState = rememberLazyGridState(),
    dynamicViewModel: DynamicViewModel = koinViewModel()
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var currentFocusedIndex by remember { mutableIntStateOf(-1) }

    // 新增：获取LazyGrid当前可见item的索引范围（解决“item已添加但未渲染”问题）
    val visibleItemIndices by remember(lazyGridState.layoutInfo) {
        derivedStateOf {
            val layoutInfo = lazyGridState.layoutInfo
            layoutInfo.visibleItemsInfo.map { it.index }.toSet()
        }
    }

    // 优化加载触发时机，提前6项开始加载+避免重复加载
    val shouldLoadMore by remember {
        derivedStateOf {
            dynamicViewModel.dynamicVideoList.isNotEmpty() &&
                    currentFocusedIndex + 6 > dynamicViewModel.dynamicVideoList.size &&
                    !dynamicViewModel.loadingVideo
        }
    }

    val showTip by remember {
        derivedStateOf { dynamicViewModel.dynamicVideoList.isNotEmpty() && currentFocusedIndex >= 0 }
    }

    // 新增：获取列表最大有效索引
    val maxValidIndex by remember {
        derivedStateOf { dynamicViewModel.dynamicVideoList.size - 1 }
    }

    // 新增：Grid焦点请求器，用于焦点管理
    val gridFocusRequester = remember { FocusRequester() }

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

    // 加载更多逻辑（原有逻辑保留）
    LaunchedEffect(shouldLoadMore) {
        if (shouldLoadMore) {
            scope.launch(Dispatchers.IO) {
                dynamicViewModel.loadMoreVideo()
            }
        }
    }

    if (dynamicViewModel.isLogin) {
        val padding = dimensionResource(R.dimen.grid_padding)
        val spacedBy = dimensionResource(R.dimen.grid_spacedBy)

        if (showTip) {
            Text(
                modifier = Modifier.fillMaxWidth().offset(x = (-20).dp, y = (-8).dp),
                text = stringResource(R.string.entry_follow_screen),
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
                fontSize = 12.sp,
                textAlign = TextAlign.End
            )
        }

        ProvideListBringIntoViewSpec {
            LazyVerticalGrid(
                modifier = modifier
                    .fillMaxSize()
                    .focusRequester(gridFocusRequester)
                    .onFocusChanged {
                        if (!it.isFocused) {
                            currentFocusedIndex = -1
                        }
                    }
                    // 核心优化1：拦截下键所有事件（KeyDown + KeyRepeat），阻止焦点溢出
                    .onPreviewKeyEvent { event ->
                        // 菜单键原有逻辑保留
                        if (event.type == KeyEventType.KeyUp && event.key == Key.Menu) {
                            context.startActivity(Intent(context, FollowActivity::class.java))
                            return@onPreviewKeyEvent true
                        }

                        // 拦截向下方向键的KeyDown和KeyRepeat（覆盖长按连续事件）
                        val isDownKey = event.key == Key.DirectionDown
                        val isDownEventType = event.type == KeyEventType.KeyDown || event.type == KeyEventType.KeyRepeat
                        val isLastValidIndex = currentFocusedIndex == maxValidIndex
                        val nextItemNotVisible = currentFocusedIndex + 1 <= maxValidIndex && !visibleItemIndices.contains(currentFocusedIndex + 1)

                        // 满足“下键+（已到最后一项/下一项未渲染）”则拦截
                        if (isDownKey && isDownEventType && (isLastValidIndex || nextItemNotVisible)) {
                            return@onPreviewKeyEvent true
                        }

                        false
                    }
                    // 核心优化2：重写focusSearch，限定焦点仅在Grid内部流转
                    .onFocusEvent { focusState ->
                        if (focusState.isFocused) {
                            (focusState as? FocusStateImpl)?.let { state ->
                                state.focusSearch = { focusedView, direction ->
                                    when (direction) {
                                        // 仅允许向下搜索，且必须是已渲染的item
                                        View.FOCUS_DOWN -> {
                                            val nextIndex = currentFocusedIndex + 1
                                            if (nextIndex <= maxValidIndex && visibleItemIndices.contains(nextIndex)) {
                                                focusedView.findViewWithTag<View>("VideoCard_$nextIndex") ?: focusedView
                                            } else {
                                                focusedView // 下一项不可用，保持当前焦点
                                            }
                                        }
                                        // 其他方向（左/上/右）按原有规则处理（保证正常退出逻辑）
                                        else -> {
                                            FocusFinder.getInstance().findNextFocus(state.host, focusedView, direction)
                                        }
                                    }
                                }
                            }
                        }
                    },
                columns = GridCells.Fixed(4),
                state = lazyGridState,
                contentPadding = PaddingValues(padding),
                verticalArrangement = Arrangement.spacedBy(spacedBy),
                horizontalArrangement = Arrangement.spacedBy(spacedBy)
            ) {
                itemsIndexed(dynamicViewModel.dynamicVideoList) { index, item ->
                    SmallVideoCard(
                        modifier = Modifier.tag("VideoCard_$index"), // 新增：给item打唯一Tag，用于focusSearch定位
                        data = remember(item.aid) {
                            VideoCardData(
                                avid = item.aid,
                                title = item.title,
                                cover = item.cover,
                                play = item.play,
                                danmaku = item.danmaku,
                                upName = item.author,
                                time = item.duration * 1000L,
                                pubTime = item.pubTime,
                                isChargingArc = item.isChargingArc,
                                badgeText = item.chargingArcBadge
                            )
                        },
                        onClick = { onClickVideo(item) },
                        onLongClick = { onLongClickVideo(item) },
                        // 核心优化3：强化焦点索引校验，仅允许可见且有效索引更新焦点
                        onFocus = {
                            if (index <= maxValidIndex && visibleItemIndices.contains(index)) {
                                currentFocusedIndex = index
                            }
                        }
                    )
                }

                // 加载中提示（原有逻辑保留）
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

                // 无更多数据提示（原有逻辑保留）
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
        // 未登录提示（原有逻辑保留）
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(text = "请先登录")
        }
    }
}
